import { 
    Button, 
    Card, 
    Divider, 
    Flex, 
    Grid, 
    Icon, 
    List, 
    ListItem, 
    Metric, 
    Subtitle, 
    TextInput, 
    Title 
} from "@tremor/react"

import { PlusIcon, SaveIcon } from "@heroicons/react/solid"
import { useEffect, useState } from "react"
import { API_URL } from "../App"
import { useCategories } from "../hooks/categories"
import { PencilIcon, TrashIcon } from "@heroicons/react/outline"
import { createCategory, deleteCategory, updateCategory } from "../components/services/categories"
import { currencyFormatter } from "../helpers/dateFormatter"
import { useFeatureFlags } from "../hooks/featureFlags"
import Loader from "../components/Loader"
import ContainerCard from "../components/ContainerCard"
import SideMenu from "../components/SideMenu"
import { useNavigate } from "react-router-dom"

function Settings() {
    const navigate = useNavigate()
    const categories = useCategories()
    const featureFlags = useFeatureFlags()
    const [settings, setSettings] = useState(JSON.parse(sessionStorage.getItem('settings')))
    const [localCategories, setLocalCategories] = useState(null)
    const [localFeatureFlags, setLocalFeatureFlags] = useState(null)

    const saveSettings = async () => {
        const response = await fetch(API_URL + '/settings', {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(settings)
        })

        const data = await response.json()
        console.log(data)
    }

    const toggleFeatureFlag = async (flag) => {
        localStorage.removeItem('featureFlags')
        const response = await fetch(API_URL + '/settings/flags/' + flag.key, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' }
        })

        const data = await response.json()
        if (data) setLocalFeatureFlags(data)
    }

    const createCategoryAction = async () => {
        const name = prompt("Nombre de la categoria")
        if (!name) return alert("Debes ingresar un nombre para la categoria")

        let response = await createCategory(name)
        if (response) setLocalCategories((old) => [...old, {id: response, name: name, products: 0}])
    }

    const deleteCategoryAction = async (category) => {
        let response = await deleteCategory(category.id)
        if (response.status === 200) setLocalCategories((old) => old.filter((c) => c.id !== category.id))
    }

    const updateCategoryAction = async (category) => {
        let response = await updateCategory(category.id, category.title)
        if (response.status === 200) setLocalCategories((old) => old.map((c) => c.id === category.id ? category : c))
    }

    useEffect(() => {
        setLocalCategories(categories)
    }, [categories])

    useEffect(() => {
        setLocalFeatureFlags(featureFlags)
    }, [featureFlags])

    if (localCategories == null || localFeatureFlags == null) {
        return <Loader />
    }

    return (
    <SideMenu>
        <ContainerCard
            title="Generales" 
            subtitle="Ajustes"
            action={
                <Button onClick={(e) => saveSettings() } icon={SaveIcon}>Guardar</Button>
            }>

            <TextInput value={ settings.siteName } onChange={ (e) => setSettings({ ...settings, siteName: e.target.value }) } className="my-2" placeholder="Nombre de la tienda" />
            <TextInput value={ settings.siteDescription } onChange={ (e) => setSettings({ ...settings, siteDescription: e.target.value }) } className="my-2" placeholder="Descripcion de la tienda" />
            <TextInput value={ settings.siteUrl } onChange={ (e) => setSettings({ ...settings, siteUrl: e.target.value }) } className="my-2" placeholder="URL de la tienda" />
        </ContainerCard>

        <Card className="mt-2">
            <Subtitle>Los costos operativos son costos que se incurren en el proceso de mantenimiento y administración de una empresa. Estos pueden ser costos fijos o variables que se incurren en el proceso de producción o venta de bienes y servicios. Algunos ejemplos de costos operativos son: alquiler, salarios, seguros, servicios públicos, etc.</Subtitle>
            <Flex>
                <Metric className="mt-1">Costos Operativos</Metric>
                <div className="flex gap-2 mt-4">
                    <Button 
                        onClick={ (e) => { navigate('/add-cost') }}
                        icon={PlusIcon}>Agregar</Button>
                </div>
            </Flex>
        </Card>

        <Grid numItems={1} numItemsSm={2}  className="mt-2 gap-2">
            <Card>
                <Metric>Feature Flags</Metric>
                <Subtitle className="mt-2">Los feature flags son una técnica de desarrollo de software que consiste en desacoplar el despliegue de código de la liberación de funcionalidades. Esto permite a los desarrolladores desplegar código en producción que no está terminado y que no es visible para los usuarios finales.</Subtitle>
            
                <List className="mt-2">
                    <ListItem>
                        <span className=""><strong>Nombre</strong></span>
                        <span className=""><strong>Estado</strong></span>
                    </ListItem>
                    {localFeatureFlags.results.map((flag) => (
                        <ListItem key={flag.key}>
                            <span className="">{flag.key}</span>
                            <span className="">
                                <Button 
                                    onClick={ (e) => toggleFeatureFlag(flag) }
                                    variant={flag.active ? 'primary' : 'secondary'}>{flag.active ? 'ON' : 'OFF'}</Button>
                            </span>
                        </ListItem>
                    ))}
                </List>
            </Card>

            <Card>
                <Metric>PostHog: Configuration</Metric>
                <Subtitle className="mt-2">La aplicación PostHog es una herramienta de analítica de código abierto que permite a los equipos de ingeniería y producto rastrear, analizar y comprender el comportamiento de los usuarios en sus aplicaciones y sitios web. Vapor Commerce utiliza PostHog para analizar el comportamiento de los usuarios en la plataforma.</Subtitle>

                <TextInput value={ settings.postHog.projectId } onChange={ (e) => setSettings({ ...settings, postHog: { ...settings.postHog, projectId: e.target.value } }) } className="my-2" placeholder="PostHog Project ID" />
                <TextInput value={ settings.postHog.apiKey } onChange={ (e) => setSettings({ ...settings, postHog: { ...settings.postHog, apiKey: e.target.value } }) } className="my-2" placeholder="PostHog Public Key" />
                <TextInput value={ settings.postHog.host } onChange={ (e) => setSettings({ ...settings, postHog: { ...settings.postHog, host: e.target.value } }) } className="my-2" placeholder="PostHog API Key" />
                <Divider />
                <Button 
                    variant="secondary"
                    onClick={ (e) => window.open('https://app.posthog.com', '_blank')}
                    className="my-2 w-full">Ver Analiticas</Button>
                <Button
                    onClick={ (e) => window.open('https://app.posthog.com/feature_flags', '_blank')}
                    className="my-2 w-full" color="amber" variant="secondary">Crear flags requeridos</Button>

            </Card>
        </Grid>
        <Grid numItems={1} numItemsSm={2}  className="gap-2">

            <Card className="mt-2">
                <Flex>
                    <div className="flex-1">
                        <Metric>Categories</Metric>
                        <Subtitle className="mt-2">Las categorias son una forma de organizar los productos en tu tienda. Puedes crear categorias para organizar tus productos por tipo, por ejemplo, camisetas, pantalones, etc.</Subtitle>
                    </div>
                    <div className="flex-none">
                        <Button 
                            onClick={ (e) => { createCategoryAction() }}
                            icon={PlusIcon}>Agregar</Button>
                    </div>
                </Flex>
                <List>
                    { localCategories.map((category) => (
                        <ListItem key={category.id}>
                            <span className="">{category.title || category.name || category.id} ({category.products})</span>
                            <span className="">
                                <Icon
                                    className="cursor-pointer"
                                    color="gray"
                                    icon={PencilIcon}
                                    onClick={ (e) => {
                                        const name = prompt("Nombre de la categoria", category.title)
                                        if (!name) return alert("Debes ingresar un nombre para la categoria")
                                        updateCategoryAction({ ...category, title: name })
                                    }
                                } />
                                <Icon
                                    className="cursor-pointer"
                                    color={category.products > 0 ? "gray" : "rose"}
                                    onClick={ (e) => {
                                        if (category.products > 0) {
                                            alert("No puedes eliminar una categoria con productos asociados")
                                            return
                                        }
                                        if (window.confirm(`
¿Estas seguro de eliminar esta categoria?\n\n
ADVERTENCIA: Todos los productos asociados a esta categoria seran eliminados!. Esta accion no se puede deshacer.\n
ASEGURATE DE ACTUALIZAR LOS PRODUCTOS ANTES DE ELIMINAR ESTA CATEGORIA.`)) 
                                        {
                                            console.log("Deleting category with id: " + category.id)
                                            deleteCategoryAction(category)
                                        }
                                    }}
                                    icon={TrashIcon} />
                            </span>
                        </ListItem>
                    ))}
                </List>
            </Card>
            <Card className="mt-2">
                <Flex>
                    <div className="flex-1">
                        <Metric>Wompi</Metric>
                        <Subtitle className="mt-2">Wompi es un proveedor de pagos que permite a los usuarios pagar con tarjeta de credito, PSE, efectivo y otros metodos de pago.</Subtitle>
                    </div>
                    <div className="flex-none">
                        
                    </div>
                </Flex>
                <Divider />
                <Title>Costs</Title>
                <List>
                    <ListItem>
                        <span className="">Costo fijo de transaccion</span>
                        <span className="">{ currencyFormatter(settings.wompi.costs.fixed) } { settings.wompi.costs.currency }</span>
                    </ListItem>
                    <ListItem>
                        <span className="">Cargo de transaccion</span>
                        <span className="">{ settings.wompi.costs.fee * 100 }%</span>
                    </ListItem>
                </List>
                <Divider />
                <Title>Monedas aceptadas</Title>
                <List>
                    {settings.availableCurrencies.map((currency) => {
                        return (
                            <ListItem key={currency}>
                                <span className="">{ currency }</span>
                            </ListItem>
                        )
                    })}
                </List>
            </Card>
        </Grid>
    </SideMenu>
  );
}

export default Settings